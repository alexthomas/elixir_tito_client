defmodule Tito.Documentation do


  defstruct [:endpoint, :module, :request_type, :function, :desc, :required_params,
    :optional_params, :errors, :raw]

  def new(json, file_name) do
    IO.puts "file name: #{file_name}"
    [module_name, function_name] = String.replace(file_name, ".json", "")
    |> String.split(".", parts: 2)

    function_name = function_name |> Macro.underscore |> String.to_atom

    %__MODULE__{
      module: module_name,
      endpoint: "#{module_name}",
      request_type: get_request_type(function_name),
      function: function_name,
      desc: json["desc"],
      required_params: get_required_params(json),
      optional_params: get_optional_params(json),
      errors: json["errors"],
      raw: json,
    }
  end

  def arguments(documentation) do
    documentation.required_params
    |> Enum.map(&(Macro.var(&1, nil)))
  end

  def arguments_with_values(documentation) do
    documentation
    |> arguments
    |> Enum.reduce([], fn(var = {arg, _, _}, acc) ->
      [{arg, var} | acc]
    end)
  end

  defp get_required_params(json), do: get_params_with_required(json, true)
  defp get_optional_params(json), do: get_params_with_required(json, false)

  defp get_params_with_required(%{"args" => args}, required) do
    args
    |> Enum.filter(fn({_, meta}) ->
      if required do
        meta["required"]
      else
        !meta["required"]
      end
    end)
    |> Enum.map(fn({name, _meta}) ->
      name |> String.to_atom
    end)
  end
  defp get_params_with_required(_json, _required) do
    []
  end

  def path do
    "#{__DIR__}/docs"
  end

  def get_request_type(:create), do: "post"
  def get_request_type(:update), do: "patch"
  def get_request_type(:destroy), do: "destroy"
  def get_request_type(_), do: "get"

end
