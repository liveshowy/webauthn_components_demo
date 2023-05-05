defmodule Demo.Repo.Migrations.RemoveUserHandleFromUserKeys do
  use Ecto.Migration

  def change do
    alter table(:user_keys) do
      remove :user_handle
    end
  end
end
