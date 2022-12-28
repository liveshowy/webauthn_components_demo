defmodule Demo.Repo.Migrations.CreateUserProfiles do
  use Ecto.Migration

  def change do
    create table(:user_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :username, :string, size: 80
      add :email, :string, size: 120

      timestamps()
    end

    create unique_index(:user_profiles, [:user_id])
    create unique_index(:user_profiles, [:email])
    create unique_index(:user_profiles, [:username])
  end
end
