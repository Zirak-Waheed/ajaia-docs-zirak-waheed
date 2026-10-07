class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.string :title, null: false
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    create_table :document_shares do |t|
      t.references :document, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "editor"
      t.timestamps
    end
    add_index :document_shares, [ :document_id, :user_id ], unique: true
  end
end
