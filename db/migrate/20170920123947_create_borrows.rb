class CreateBorrows < ActiveRecord::Migration[5.1]
  def change
    create_table :borrows do |t|
      t.string :borrower
      t.integer :book_id

      t.timestamps
    end
  end
end
