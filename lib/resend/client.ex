defmodule Resend.Client do
  @moduledoc """
  Resend API client.
  """

  require Logger

  alias Resend.Castable

  @callback post(t(), String.t(), map()) ::
              {:ok, %{body: map(), status: pos_integer()}} | {:error, any()}

  @type response(type) :: {:ok, type} | {:error, Resend.Error.t() | :client_error}

  @type t() :: %__MODULE__{
          api_key: String.t(),
          base_url: String.t() | nil,
          client: module() | nil
        }

  @enforce_keys [:api_key, :base_url, :client]
  defstruct [:api_key, :base_url, :client]

  @default_opts [
    base_url: "https://api.resend.com",
    client: __MODULE__.TeslaClient
  ]

  @doc """
  Returns a new Resend client struct.

  Accepts a keyword list of config opts, though if omitted then it will attempt to load
  them from the application environment.
  """
  @spec new() :: t()
  @spec new(Resend.config()) :: t()
  def new(config \\ Resend.config()) do
    struct!(__MODULE__, Keyword.merge(@default_opts, config))
  end

  @spec post(t(), String.t(), atom(), map()) :: response(any())
  def post(client, path, castable_module, body) do
    client_module = client.client || Resend.Client.TeslaClient

    case client_module.post(client, path, body) do
      {:ok, %{body: body, status: status}} when status in 200..299 ->
        {:ok, Castable.cast(castable_module, body)}

      {:ok, %{body: body}} ->
        {:error, Castable.cast(Resend.Error, body)}

      {:error, reason} ->
        Logger.error("#{inspect(__MODULE__)} error when calling #{path}: #{inspect(reason)}")
        {:error, :client_error}
    end
  end
end
