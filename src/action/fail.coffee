
# ----------------------------------------------------------------------------
# The Fail action unconditionally fails. It is useful if the resource should
# be created by some other action and you just want to verify its presence.
# ----------------------------------------------------------------------------

module.exports = ->
  return (targets) ->
    return Futures.future().deliver new Error "Unconditionally failing #{targets}"

