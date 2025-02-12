# app/controllers/home_controller.rb
require "csv"
require 'zip'

class HomeController < ApplicationController
  def index
    @documents = Document.all
    if session[:csv_data].present?
      # Get the first row and transform keys to symbols
      first_row = session[:csv_data].first
      @preview_data = first_row.transform_keys(&:to_sym)
    else
      @preview_data = {
        business_name: "Default Business Name",
        employer_name: "Default Employer Name",
        employer_email: "default@example.com",
        employer_contact: "000-000-0000",
        employer_address: "Default Address",
        employee_name: "Default Employee Name",
        employee_email: "default@example.com",
        employee_contact: "000-000-0000",
        employee_address: "Default Address",
        duration_months: "0"
      }
    end
  end

  def upload_csv
    service = EmploymentContractService.new
    
    begin
      session[:csv_data] = service.process_csv(params[:file])
      flash[:notice] = "CSV with #{session[:csv_data].size} rows uploaded successfully!"
    rescue EmploymentContractService::InvalidCSVError => e
      flash[:alert] = e.message
      session[:csv_data] = nil
    end
    
    redirect_to root_path
  end

  def download_pdf
    return redirect_to(root_path, alert: "No CSV data available") unless session[:csv_data]

    service = EmploymentContractService.new
    
    begin
      zip_data = service.generate_pdfs(session[:csv_data])
      
      send_data zip_data,
                filename: 'EmploymentContracts.zip',
                type: 'application/zip',
                disposition: 'attachment'
    rescue StandardError => e
      redirect_to root_path, alert: "Error generating PDFs: #{e.message}"
    end
  end
end