if defined?(::ActiveRecord)
  ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

  ActiveRecord::Schema.define do
    self.verbose = false

    create_table :books, force: true do |t|
      t.string :title, null: false
      t.string :authors, null: false
      t.string :isbn10, null: false
      t.integer :pages
      t.date :release_date, null: false
      t.timestamps null: false
    end

    add_index :books, :isbn10, unique: true
  end

end
