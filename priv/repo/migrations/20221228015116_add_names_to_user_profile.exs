defmodule Demo.Repo.Migrations.AddNamesToUserProfile do
  use Ecto.Migration

  def change do
    alter table(:user_profiles) do
      add :first_name, :string, after: :email
      add :last_name, :string, after: :first_name
    end
  end
end
