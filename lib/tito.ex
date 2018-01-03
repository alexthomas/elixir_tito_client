defmodule Tito do
  alias Tito.Documentation
  @moduledoc """
  Documentation for Tito.
  """
  def documentation do
    File.ls!(Documentation.path)
    |> format_documentation
  end

  defp format_documentation(files) do
    Enum.reduce(files, %{}, fn(file, module_names) ->
      IO.puts "parsing file: #{file}"
      json =
        File.read!("#{Documentation.path}/#{file}")
        |> Poison.Parser.parse!()

      doc = Documentation.new(json, file)

      module_names
      |> Map.put_new(doc.module, [])
      |> update_in([doc.module], &(&1 ++ [doc]))
    end)
  end
end

alias Tito.Documentation

Enum.each(Tito.documentation, fn({module_name, functions}) ->
  module_name = module_name |> Macro.camelize
  module = Module.concat(Tito, module_name)

  defmodule module do
    Enum.each(functions, fn(doc) ->
      function_name = doc.function
      arguments = Documentation.arguments(doc)
      argument_value_keyword_list = Documentation.arguments_with_values(doc)
      def unquote(function_name)(unquote_splicing(arguments), optional_params \\ %{}, token \\ nil ) do
        required_params = unquote(argument_value_keyword_list)
        url = Tito.Client.url(optional_params, unquote(doc.api))

        params = optional_params
        |> Enum.reject(fn {k, _} -> !Enum.member?(unquote(doc.optional_params),  k) end)
        |> Keyword.merge(required_params)
        |> Keyword.put(:type, unquote(doc.module))
        |> Enum.reject(fn {_, v} -> v == nil end)
        |> Enum.into(%{})

        endpoint = Tito.Client.endpoint(url, unquote(doc.endpoint), params)
        apply(Tito.Client, String.to_atom("#{unquote(doc.request_type)}"), [endpoint, params, [{"Authorization", "Token token=#{Tito.Client.access_token(token)}"}]])
      end
    end)
  end
end)
