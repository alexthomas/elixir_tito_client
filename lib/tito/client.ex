defmodule Tito.Client do
  use HTTPoison.Base

  # def post!(url, body, headers \\ [], options \\ []),  do: request!(:post, url, body, headers, options)
  def post(url, params \\ %{}, headers \\ []) do
    data = %{
      data: %{
        type: Map.fetch!(params, :type),
        attributes: Map.delete(params, :type)
      }
    }
    IO.puts url
    IO.puts headers |> inspect
    IO.puts Poison.encode!(data) |> inspect
    headers = headers
    |> request_headers

    IO.puts "url: #{url}"
    HTTPoison.request!(:post, url, Poison.encode!(data), headers)
  end

   def patch(url, params \\ %{}, headers \\ []) do
    data = %{
      data: %{
        id: Map.fetch!(params, :id),
        type: Map.fetch!(params, :type),
        attributes: Map.drop(params, [:id, :type])
      }
    }
    HTTPoison.request!(:patch, url, Poison.encode!(data), headers, [])
    |> handle_response
  end

  def put(url, params \\ %{}, headers \\ []) do
    data = %{
      data: %{
        id: Map.fetch!(params, :id),
        type: Map.fetch!(params, :type),
        attributes: Map.drop(params, [:id, :type])
      }
    }
    HTTPoison.request!(:put, url, Poison.encode!(data), headers, [])
    |> handle_response
  end

  # def get!(url, headers \\ [], options \\ [])
  def get(url, options \\ %{}, headers \\ []) do
    headers = headers
    |> request_headers
    HTTPoison.get!(url, headers)
    |> handle_response
  end

  def  handle_response(%HTTPoison.Response{status_code: 200, body: body}), do: {:ok, body |> process_response_body}
  def  handle_response(%HTTPoison.Response{status_code: 201, body: body}), do: {:ok, body |> process_response_body}
  def  handle_response(%HTTPoison.Response{status_code: ___, body: body}), do: {:error, body}
  def  handle_response(%HTTPoison.Error{reason: reason}), do: {:error, reason}

  defp process_response_body(body) do
    body
    |> Poison.decode!
  end

  defp request_headers(headers) do
    headers ++ [
      {"Content-Type", "application/vnd.api+json"},
      {"Accept", "application/vnd.api+json"}
    ]
  end

  def access_token(nil), do: Application.get_env(:tito, :api_key)
  def access_token(token), do: token

  def url(%{url: url}), do: url
  def url(%{account: account}), do: Application.get_env(:tito, :url, "https://api.tito.io/v2/#{account}")
  def url(_), do: Application.get_env(:tito, :url, "https://api.tito.io/v2/#{account()}")

  def endpoint(url, "events", %{id: id}), do: "#{url}/#{id}"
  def endpoint(url, "events", _), do: "#{url}/events"
  def endpoint(url, module, %{id: id, event_id: event_id}), do: "#{url}/#{event_id}/#{module}/#{id}"
  def endpoint(url, module, %{event_id: event_id}), do: "#{url}/#{event_id}/#{module}"
  def endpoint(url, _, _), do: url

  defp account, do: Application.get_env(:tito, :account)
end
