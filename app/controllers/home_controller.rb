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
      redirect_to managefile_path
    rescue EmploymentContractService::InvalidCSVError => e
      flash[:alert] = e.message
      session[:csv_data] = nil
      set_template_and_preview_data # Call the helper method
      render :managefile # Render the same page instead of redirecting
    end
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

  def managefile
    set_template_and_preview_data # Call the helper method
    Rails.logger.info "Selected template: #{params[:template]}"
    Rails.logger.info "Rendering partial: #{@template_partial}"
  end

  private

  def set_template_and_preview_data
    template = params[:template] || 'default' # Default to 'default' if no template is provided
    @template_partial = case template
                        when 'default'
                          'home/template'
                        when 'template_1'
                          'home/template_1'
                        when 'template_2'
                          'home/template_2'
                        when 'template_3'
                          'home/template_3'
                        else
                          'home/template'
                        end
  
    # Use session[:csv_data] or default data for the preview
    if session[:csv_data].present?
      @preview_data = session[:csv_data].first.transform_keys(&:to_sym)
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
end