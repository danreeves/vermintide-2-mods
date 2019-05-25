local mod = get_mod("dadjokes")

local function handle_response(success, status_code, response_headers, data)
  local data = cjson.decode(data)
  mod:chat_broadcast(data.joke)
end

mod:command('dadjoke', "Get a random dad joke", function()
  local url = "https://icanhazdadjoke.com/"
  local headers = {
    "Accept: application/json",
    "User-Agent: Vermintide 2 Mod - Dad Jokes",
  }
  -- url, headers, request_cb, userdata, options
  Managers.curl:get(url, headers, handle_response, nil, {})
end)
