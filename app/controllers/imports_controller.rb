class ImportsController < ApplicationController
  def create
    result = DocumentImporter.call(params[:file])
    document = Current.user.owned_documents.create!(title: result.title, body: result.html)
    redirect_to edit_document_path(document), notice: "Imported #{params[:file].original_filename} as a new document."
  rescue DocumentImporter::Error => e
    redirect_to documents_path, alert: e.message
  end
end
