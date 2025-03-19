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
        full_name: "Full Name",
        title: "Default Employer Name",
        position: "default@example.com",
        short_name: "000-000-0000",
        last_name: "Default Address",
        course_code: "Default Employee Name",
        team_name: "default@example.com",
        amount: "0"
      }
    end
  end

  def upload_csv
    service = EmploymentContractService.new
  
    begin
      session[:csv_data] = service.process_csv(params[:file])
      flash[:notice] = "CSV uploaded successfully!"
      redirect_to managefile_path
    rescue EmploymentContractService::InvalidCSVError => e
      flash[:alert] = e.message # Display the error message
      redirect_to managefile_path
    end
  end
  
  

  def download_pdf
    return redirect_to(root_path, alert: "No CSV data available") unless session[:csv_data]

    service = EmploymentContractService.new
    
    begin
      zip_data = service.generate_pdfs(session[:csv_data])
      
      send_data zip_data,
                filename: 'StudentContracts.zip',
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
        full_name: "Default Business Name",
        title: "Default Employer Name",
        position: "default@example.com",
        short_name: "000-000-0000",
        last_name: "Default Address",
        course_code: "Default Employee Name",
        team_name: "default@example.com",
        amount: "0"
      }
    end
  end
end