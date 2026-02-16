class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes do |t|
      t.references :task, null: false, foreign_key: true
      t.text :content
      t.string :author
      t.integer :user_id

      t.timestamps
    end
  end
end
