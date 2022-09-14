class AddDoublesToPlayers < ActiveRecord::Migration[4.2]
  def change
    add_column :players, :team_size, :integer, null: false, default: 1
  end
end
