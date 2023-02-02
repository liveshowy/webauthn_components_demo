defmodule Demo.Authentication.UserToken do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Demo.Accounts.User

  @rand_size 32
  @session_validity_in_days 7

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_tokens" do
    field :context, Ecto.Enum, values: [:session], default: :session
    field :token, :binary
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = user_token, attrs) do
    user_token
    |> cast(attrs, [:token, :context, :user_id])
    |> validate_required([:token, :context, :user_id])
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.

  The reason why we store session tokens in the database, even
  though Phoenix already provides a session cookie, is because
  Phoenix' default session cookies are not persisted, they are
  simply signed and potentially encrypted. This means they are
  valid indefinitely, unless you change the signing/encryption
  salt.

  Therefore, storing them allows individual user
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  You could then use this information to display all valid sessions
  and devices in the UI and allow users to explicitly expire any
  session they deem invalid.
  """
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    %__MODULE__{token: token, context: :session, user_id: user.id}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any.

  The token is valid if it matches the value in the database and it has
  not expired (after @session_validity_in_days).
  """
  def verify_session_token_query(token) do
    from token in token_and_context_query(token, :session),
      join: user in assoc(token, :user),
      where: token.inserted_at > ago(@session_validity_in_days, "day"),
      select: user
  end

  @doc """
  Returns the token struct for the given token value and context.
  """
  def token_and_context_query(token, context) do
    from Demo.Authentication.UserToken, where: [token: ^token, context: ^context]
  end
end
