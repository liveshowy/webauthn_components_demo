defmodule WebauthnComponentsDemo.Accounts.PublicKeyCredential do
  use Ecto.Schema
  import Ecto.Changeset
  alias WebauthnComponentsDemo.Accounts.User

  @primary_key {:id, :binary, autogenerate: false}
  @foreign_key_type :binary_id
  schema "public_key_credentials" do
    field :label, :string, default: "Default"
    field :public_key, WebauthnComponents.CoseKey
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def register_changeset(public_key_credential, attrs) do
    public_key_credential
    |> cast(attrs, [:id, :label, :public_key, :user_id])
    |> validate_required([:id, :label, :public_key, :user_id])
  end

  def label_changeset(public_key_credential, attrs) do
    public_key_credential
    |> cast(attrs, [:label])
    |> validate_required([:label])
  end
end
