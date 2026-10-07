class SharesController < ApplicationController
  before_action :set_owned_document

  def create
    email = params[:email_address].to_s.strip.downcase
    user = User.find_by(email_address: email)

    if user.nil?
      redirect_to edit_document_path(@document), alert: "No account found for #{email.presence || 'that email'}."
      return
    end

    share = @document.shares.build(user: user, role: params[:role].presence || "editor")
    if share.save
      redirect_to edit_document_path(@document), notice: "Shared with #{user.email_address} (#{share.role})."
    else
      redirect_to edit_document_path(@document), alert: share.errors.full_messages.to_sentence
    end
  end

  def destroy
    @document.shares.find(params[:id]).destroy!
    redirect_to edit_document_path(@document), notice: "Access removed."
  end

  private

  # Only owners manage sharing; anyone else gets a 404.
  def set_owned_document
    @document = Current.user.owned_documents.find(params[:document_id])
  end
end
