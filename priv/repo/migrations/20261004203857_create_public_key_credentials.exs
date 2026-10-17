defmodule WebauthnComponentsDemo.Repo.Migrations.CreatePublicKeyCredentials do
  use Ecto.Migration

  def change do
    create table(:public_key_credentials, primary_key: false) do
      add :id, :bytea, primary_key: true
      add :label, :string
      add :public_key, :binary
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:public_key_credentials, [:user_id])
  end
end
