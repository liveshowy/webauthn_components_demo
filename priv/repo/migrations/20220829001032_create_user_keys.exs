defmodule Demo.Repo.Migrations.CreateUserKeys do
  use Ecto.Migration

  def change do
    create table(:user_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :key_id, :binary, nil: false
      add :public_key, :binary, nil: false
      add :label, :string, nil: false
      add :last_used, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:user_keys, [:user_id])
    create unique_index(:user_keys, [:key_id])
    create unique_index(:user_keys, [:user_id, :label])
  end
end
