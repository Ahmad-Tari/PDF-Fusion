class EmploymentContractService
  class InvalidCSVError < StandardError; end # Custom error for invalid CSV

  # Define required columns
  REQUIRED_COLUMNS = [
    "full_name",
    "title",
    "position",
    "short_name",
    "last_name",
    "course_code",
    "team_name",
    "amount"
  ].freeze

  BATCH_SIZE = 5

  def initialize
    @processed_rows = 0
    @total_rows = 0
  end

  # Process the uploaded CSV file
  def process_csv(file)
    validate_csv_file(file) # Validate file before processing
    csv_data = CSV.parse(file.read, headers: true)

    # Validate headers
    validate_csv_headers(csv_data.headers)

    csv_data.map(&:to_hash)
  end

  # Generate PDFs from CSV data
  def generate_pdfs(csv_data)
    @total_rows = csv_data.size
    @processed_rows = 0

    Dir.mktmpdir do |temp_dir|
      csv_data.each_slice(BATCH_SIZE) do |batch|
        generate_batch_pdfs(batch, temp_dir)
      end
      create_zip_file(temp_dir)
      File.read(File.join(temp_dir, 'StudentContracts.zip'))
    end
  end

  private

  # Validate CSV file
  def validate_csv_file(file)
    raise InvalidCSVError, "No file uploaded" if file.nil?

    # Check the file extension
    unless File.extname(file.original_filename).casecmp?(".csv")
      raise InvalidCSVError, "Invalid file type. Only CSV files are allowed."
    end

    # Check MIME type
    allowed_mime_types = ["text/csv", "application/vnd.ms-excel"]
    unless allowed_mime_types.include?(file.content_type)
      raise InvalidCSVError, "Invalid file format. Please upload a valid CSV file."
    end
  end

  # Validate CSV headers
  def validate_csv_headers(headers)
    missing_columns = REQUIRED_COLUMNS - headers
    if missing_columns.any?
      raise InvalidCSVError, "Missing required columns: #{missing_columns.join(', ')}"
    end
  end

  # Generate PDFs for a batch of rows
  def generate_batch_pdfs(batch, temp_dir)
    batch.each_with_index do |row, index|
      generate_single_pdf(row, temp_dir, index)
      @processed_rows += 1
    end
  end

  # Generate a single PDF for a row
  def generate_single_pdf(row, temp_dir, index)
    # Convert hash keys to symbols for the template
    template_vars = row.transform_keys(&:to_sym)

    html = ApplicationController.renderer.render(
      template: 'home/_template',
      layout: false,
      locals: template_vars
    )

    pdf = WickedPdf.new.pdf_from_string(html)
    save_pdf(pdf, temp_dir, index, row)
  end

  # Save the generated PDF to a temporary directory
  def save_pdf(pdf, temp_dir, index, row)
    filename = generate_filename(row, index)
    pdf_path = File.join(temp_dir, filename)
    File.open(pdf_path, 'wb') { |file| file << pdf }
  end

  # Generate a filename for the PDF
  def generate_filename(row, index)
    safe_name = row['full_name'].gsub(/[^0-9A-Za-z]/, '_')
    "StudentContract_#{index + 1}_#{safe_name}.pdf"
  end

  # Create a ZIP file containing all PDFs
  def create_zip_file(temp_dir)
    zip_path = File.join(temp_dir, 'StudentContracts.zip')
    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      Dir[File.join(temp_dir, '*.pdf')].each do |pdf_file|
        zipfile.add(File.basename(pdf_file), pdf_file)
      end
    end
  end
end