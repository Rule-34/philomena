defmodule Philomena.Config do
  def get(key) do
    Application.get_env(:philomena, :config)[key]
  end

  def get_setting(key) do
    get(:settings)[key]
  end
end
