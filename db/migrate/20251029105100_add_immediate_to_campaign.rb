class AddImmediateToCampaign < ActiveRecord::Migration[8.0]
  def change
    add_column :campaigns, :immediate, :boolean, default: false, null: false
    add_index  :campaigns, :immediate

    # Optional backfill heuristic for existing rows:
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE campaigns
          SET immediate = TRUE
          WHERE scheduled_at IS NULL
             OR (status <> 'SCHEDULED' AND ABS(EXTRACT(EPOCH FROM (scheduled_at - created_at))) <= 120)
        SQL
      end
    end
  end
end
