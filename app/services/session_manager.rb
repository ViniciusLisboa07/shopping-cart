# frozen_string_literal: true

class SessionManager
  CART_ID_KEY = :cart_id

  def get_cart_id(session)
    session[CART_ID_KEY]
  end

  def set_cart_id(session, cart_id)
    session[CART_ID_KEY] = cart_id
  end

  def clear_cart_id(session)
    session.delete(CART_ID_KEY)
  end
end
