# app/controllers/home_controller.rb
require "csv"
require 'zip'
require 'securerandom'

class HomeController < ApplicationController
  def index
    @documents = Document.all
    if params[:file_id].present? && File.exist?(csv_file_path(params[:file_id]))
      csv_data = CSV.read(csv_file_path(params[:file_id]), headers: true)
      first_row = csv_data.first
      @preview_data = first_row.to_h.transform_keys(&:to_sym)
    else
      @preview_data = {
        full_name: "Default Full Name",
        title: "Default Title",
        position: "Default Position",
        short_name: "Default Short Name",
        last_name: "Default Last Name",
        course_code: "Default Course Code",
        team_name: "Default Team Name",
        amount: "1000"
      }
    end
  end

  def upload_csv
    service = EmploymentContractService.new

    begin
      file_id = SecureRandom.uuid # Generate a unique file ID
      csv_data = service.process_csv(params[:file])
      File.write(csv_file_path(file_id), csv_data.to_csv) # Save CSV data to a file
      flash[:notice] = "CSV uploaded successfully!"
      redirect_to managefile_path(file_id: file_id) # Pass the file ID to the next action
    rescue EmploymentContractService::InvalidCSVError => e
      flash[:alert] = e.message
      redirect_to managefile_path
    end
  end

  def download_pdf
    file_id = params[:file_id]
    return redirect_to(root_path, alert: "No CSV data available") unless file_id.present? && File.exist?(csv_file_path(file_id))

    service = EmploymentContractService.new

    begin
      csv_data = CSV.read(csv_file_path(file_id), headers: true)
      zip_data = service.generate_pdfs(csv_data.map(&:to_h))

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

  def csv_file_path(file_id)
    Rails.root.join('tmp', "csv_#{file_id}.csv") # Store CSV files in the tmp directory
  end

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

    # Use file-based CSV data or default data for the preview
    if params[:file_id].present? && File.exist?(csv_file_path(params[:file_id]))
      csv_data = CSV.read(csv_file_path(params[:file_id]), headers: true)
      @preview_data = csv_data.first.to_h.transform_keys(&:to_sym)
    else
      @preview_data = {
        full_name: "Default Full Name",
        title: "Default Title",
        position: "Default Position",
        short_name: "Default Short Name",
        last_name: "Default Last Name",
        course_code: "Default Course Code",
        team_name: "Default Team Name",
        amount: "1000"
      }
    end
  end
end