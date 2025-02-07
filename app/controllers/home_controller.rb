require "csv"

class HomeController < ApplicationController
  def index
    @documents = Document.all
  end

  def upload_csv
    if params[:file].present? && params[:file].content_type == "text/csv"
      csv_text = params[:file].read
      @csv_data = CSV.parse(csv_text, headers: true)
      flash[:notice] = "CSV uploaded successfully!"
    else
      flash[:alert] = "Please upload a valid CSV file."
    end
    redirect_to root_path
  end
  def download_pdf
    file_path = Rails.root.join("app", "assets", "documents", "EmploymentContract-En.pdf")
    if File.exist?(file_path)
      send_file file_path, filename: "EmploymentContract-En.pdf", type: "application/pdf", disposition: "attachment"
    else
      flash[:alert] = "File not found."
      redirect_to root_path
    end
  end
end
