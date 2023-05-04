defmodule Demo.Repo.Migrations.MoveEmailToUserTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :email, :string, size: 120, null: false
    end

    create unique_index(:users, [:email])

    alter table(:user_profiles) do
      remove :email
    end

    drop_if_exists index(:user_profiles, [:email])
  end
end
