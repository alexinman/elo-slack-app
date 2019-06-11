class AddDoublesToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :team_size, :integer, null: false, default: 1
  end
end
