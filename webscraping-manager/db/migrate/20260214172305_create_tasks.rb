class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :url
      t.string :status
      t.text :last_error

      t.timestamps
    end
  end
end
