class DocumentsController < ApplicationController
  before_action :set_document, only: %i[show edit update destroy]
  before_action :require_editor, only: %i[edit update]
  before_action :require_owner, only: %i[destroy]

  def index
    @owned = Document.owned_by(Current.user).includes(:owner).order(updated_at: :desc)
    @shared = Document.shared_with(Current.user).includes(:owner).order(updated_at: :desc)
  end

  # Read-only view. Editors are sent straight to the editor.
  def show
    redirect_to edit_document_path(@document) if @document.editable_by?(Current.user)
  end

  def create
    @document = Current.user.owned_documents.create!(title: "Untitled document")
    redirect_to edit_document_path(@document)
  end

  def edit
  end

  def update
    if @document.update(document_params)
      respond_to do |format|
        format.html { redirect_to edit_document_path(@document), notice: "Saved." }
        format.json { render json: { saved_at: @document.updated_at } }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @document.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @document.destroy!
    redirect_to documents_path, notice: "Document deleted."
  end

  private

  # Documents the user can't see raise RecordNotFound (404) rather than 403,
  # so their existence isn't leaked.
  def set_document
    @document = Document.accessible_by(Current.user).find(params[:id])
  end

  def require_editor
    return if @document.editable_by?(Current.user)

    respond_to do |format|
      format.html { redirect_to document_path(@document), alert: "You have view-only access to this document." }
      format.json { head :forbidden }
    end
  end

  def require_owner
    redirect_to edit_document_path(@document), alert: "Only the owner can do that." unless @document.owned_by?(Current.user)
  end

  def document_params
    params.require(:document).permit(:title, :body)
  end
end
