defmodule Demo.AuthenticationTest do
  use Demo.DataCase

  alias Demo.Authentication

  describe "user_keys" do
    alias Demo.Authentication.UserKey

    import Demo.AccountsFixtures
    import Demo.AuthenticationFixtures

    @invalid_attrs %{key_id: nil, label: nil, last_used: nil, public_key: nil}

    test "list_user_keys/0 returns all user_keys" do
      user = user_fixture()
      user_key = user_key_fixture(%{user: user})
      assert Authentication.list_user_keys() == [user_key]
    end

    test "get_user_key!/1 returns the user_key with given id" do
      user = user_fixture()
      user_key = user_key_fixture(%{user: user})
      assert Authentication.get_user_key!(user_key.id) == user_key
    end

    test "create_user_key/1 with valid data creates a user_key" do
      user = user_fixture()

      valid_attrs = %{
        key_id: "some key_id",
        label: "some label",
        last_used: ~U[2022-08-28 00:10:00Z],
        public_key: "some public_key",
        user_id: user.id
      }

      assert {:ok, %UserKey{} = user_key} = Authentication.create_user_key(valid_attrs)
      assert user_key.key_id == "some key_id"
      assert user_key.label == "some label"
      assert user_key.last_used == ~U[2022-08-28 00:10:00Z]
      assert user_key.public_key == "some public_key"
    end

    test "create_user_key/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Authentication.create_user_key(@invalid_attrs)
    end

    test "update_user_key/2 with valid data updates the user_key" do
      user = user_fixture()
      user_key = user_key_fixture(%{user: user})

      update_attrs = %{
        key_id: "some updated key_id",
        label: "some updated label",
        last_used: ~U[2022-08-29 00:10:00Z],
        public_key: "some updated public_key"
      }

      assert {:ok, %UserKey{} = user_key} = Authentication.update_user_key(user_key, update_attrs)
      assert user_key.key_id == "some updated key_id"
      assert user_key.label == "some updated label"
      assert user_key.last_used == ~U[2022-08-29 00:10:00Z]
      assert user_key.public_key == "some updated public_key"
    end

    test "update_user_key/2 with invalid data returns error changeset" do
      user = user_fixture()
      user_key = user_key_fixture(%{user: user})

      assert {:error, %Ecto.Changeset{}} =
               Authentication.update_user_key(user_key, @invalid_attrs)

      assert user_key == Authentication.get_user_key!(user_key.id)
    end

    test "delete_user_key/1 deletes the user_key" do
      user = user_fixture()
      user_key = user_key_fixture(%{user: user})
      assert {:ok, %UserKey{}} = Authentication.delete_user_key(user_key)
      assert_raise Ecto.NoResultsError, fn -> Authentication.get_user_key!(user_key.id) end
    end

    test "change_user_key/1 returns a user_key changeset" do
      user = user_fixture()
      user_key = user_key_fixture(%{user: user})
      assert %Ecto.Changeset{} = Authentication.change_user_key(user_key)
    end
  end
end
