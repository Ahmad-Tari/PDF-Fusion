require "csv"

class HomeController < ApplicationController
  def index
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
end
