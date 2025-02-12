# app/services/employment_contract_service.rb
class EmploymentContractService
    class InvalidCSVError < StandardError; end
    
    REQUIRED_HEADERS = %w[
      business_name employer_name employer_email employer_contact employer_address
      employee_name employee_email employee_contact employee_address duration_months
    ].freeze
  
    def initialize
      @processed_rows = 0
      @total_rows = 0
    end
  
    def process_csv(file)
      validate_file!(file)
      
      csv_data = parse_csv(file)
      validate_headers!(csv_data.headers)
      
      csv_data.map(&:to_hash)
    rescue CSV::MalformedCSVError => e
      raise InvalidCSVError, "Malformed CSV file: #{e.message}"
    end
  
    def generate_pdfs(csv_data)
      @total_rows = csv_data.size
      @processed_rows = 0
      
      Dir.mktmpdir do |temp_dir|
        generate_batch_pdfs(csv_data, temp_dir)
        create_zip_file(temp_dir)
        File.read(File.join(temp_dir, 'EmploymentContracts.zip'))
      end
    end
  
    private
  
    def validate_file!(file)
      raise InvalidCSVError, "No file provided" unless file.present?
      raise InvalidCSVError, "Invalid file type" unless file.content_type == "text/csv"
    end
  
    def parse_csv(file)
      CSV.parse(file.read, headers: true)
    end
  
    def validate_headers!(headers)
      missing_headers = REQUIRED_HEADERS - headers
      if missing_headers.any?
        raise InvalidCSVError, "Missing required headers: #{missing_headers.join(', ')}"
      end
    end
  
    def generate_batch_pdfs(csv_data, temp_dir)
      csv_data.each_with_index do |row, index|
        generate_single_pdf(row, temp_dir, index)
        @processed_rows += 1
      end
    end
  
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
  
    def save_pdf(pdf, temp_dir, index, row)
      filename = generate_filename(row, index)
      pdf_path = File.join(temp_dir, filename)
      File.open(pdf_path, 'wb') { |file| file << pdf }
    end
  
    def generate_filename(row, index)
      safe_name = row['employee_name'].gsub(/[^0-9A-Za-z]/, '_')
      "EmploymentContract_#{index + 1}_#{safe_name}.pdf"
    end
  
    def create_zip_file(temp_dir)
      zip_path = File.join(temp_dir, 'EmploymentContracts.zip')
      Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        Dir[File.join(temp_dir, '*.pdf')].each do |pdf_file|
          zipfile.add(File.basename(pdf_file), pdf_file)
        end
      end
    end
  end