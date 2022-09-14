class UpdateGameResultToFloat < ActiveRecord::Migration[4.2]
  def change
    change_column :games, :result, :float
  end
end
