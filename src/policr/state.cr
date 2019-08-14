alias StateValueType = Bool | Int32

STATE_TYPE_MAP = {
  :done => Bool,
}

macro read_state(name)
  {{ cls = STATE_TYPE_MAP[name] }}
  if (val = state[{{name}}]?) && (val.is_a?({{cls}}))
    val
  else
    bot.log "Setting state {{name}} in " + {{ @type.stringify }}
    val = {{yield}}
    state[{{name}}] = val

    val
  end
end
