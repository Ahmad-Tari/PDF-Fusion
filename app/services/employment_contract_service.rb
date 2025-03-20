class EmploymentContractService
  class InvalidCSVError < StandardError; end

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

  def process_csv(file)
    validate_csv_file(file)
    csv_data = CSV.parse(file.read, headers: true)
    validate_csv_headers(csv_data.headers)
    validate_csv_rows(csv_data)
    csv_data
  end

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

  def validate_csv_file(file)
    raise InvalidCSVError, "No file uploaded" if file.nil?
    unless File.extname(file.original_filename).casecmp?(".csv")
      raise InvalidCSVError, "Invalid file type. Only CSV files are allowed."
    end
    allowed_mime_types = ["text/csv", "application/vnd.ms-excel"]
    unless allowed_mime_types.include?(file.content_type)
      raise InvalidCSVError, "Invalid file format. Please upload a valid CSV file."
    end
  end

  def validate_csv_headers(headers)
    missing_columns = REQUIRED_COLUMNS - headers
    if missing_columns.any?
      raise InvalidCSVError, "Missing required columns: #{missing_columns.join(', ')}"
    end
  end

  def validate_csv_rows(csv_data)
    csv_data.each_with_index do |row, index|
      missing_values = REQUIRED_COLUMNS.select { |col| row[col].blank? }
      if missing_values.any?
        raise InvalidCSVError, "Row #{index + 1} is missing data for: #{missing_values.join(', ')}"
      end
    end
  end

  def generate_batch_pdfs(batch, temp_dir)
    batch.each_with_index do |row, index|
      generate_single_pdf(row, temp_dir, index)
      @processed_rows += 1
    end
  end

  def generate_single_pdf(row, temp_dir, index)
    template_vars = row.transform_keys(&:to_sym)
    html = ApplicationController.renderer.render(
      template: 'home/_template',
      layout: false,
      locals: template_vars
    )
    pdf = WickedPdf.new.pdf_from_string(html)
    save_pdf(pdf, temp_dir, index, row)
  end

  def save_pdf(pdf, temp_dir, index, row)
    filename = generate_filename(row, index)
    pdf_path = File.join(temp_dir, filename)
    File.open(pdf_path, 'wb') { |file| file << pdf }
  end

  def generate_filename(row, index)
    safe_name = row['full_name'].gsub(/[^0-9A-Za-z]/, '_')
    "StudentContract_#{index + 1}_#{safe_name}.pdf"
  end

  def create_zip_file(temp_dir)
    zip_path = File.join(temp_dir, 'StudentContracts.zip')
    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      Dir[File.join(temp_dir, '*.pdf')].each do |pdf_file|
        zipfile.add(File.basename(pdf_file), pdf_file)
      end
    end
  end
end