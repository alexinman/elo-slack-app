class UpdateGameResultToFloat < ActiveRecord::Migration
  def change
    change_column :games, :result, :float
  end
end
