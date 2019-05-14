module ROTP
  class Base32
    class Base32Error < RuntimeError; end
    CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'.each_char.to_a
    SHIFT = 5
    MASK = 31

    class << self

      def decode(str)
        buffer = 0
        idx = 0
        bits_left = 0
        str = str.tr('=', '').upcase
        result = []
        str.split('').each do |char|
          buffer = buffer << SHIFT
          buffer = buffer | (decode_quint(char) & MASK)
          bits_left = bits_left + SHIFT
          if bits_left >= 8
            result[idx] = (buffer >> (bits_left - 8)) & 255
            idx = idx + 1
            bits_left = bits_left - 8
          end
        end
        result.pack('c*')
      end

      def encode(b)
        data = b.unpack('c*')
        out = ''
        buffer = data[0]
        idx = 1
        bits_left = 8
        while bits_left > 0 || idx < data.length
          if bits_left < SHIFT
            if idx < data.length
              buffer = buffer << 8
              buffer = buffer | (data[idx] & 255)
              bits_left = bits_left + 8
              idx = idx + 1
            else
              pad = SHIFT - bits_left
              buffer = buffer << pad
              bits_left = bits_left + pad
            end
          end
          val = MASK & (buffer >> (bits_left - SHIFT))
          bits_left = bits_left - SHIFT
          out.concat(CHARS[val])
        end
        return out
      end

      # Defaults to 256 bit long secret
      def random(byte_length = 32)
       rand_bytes = SecureRandom.random_bytes(byte_length)
       self.encode(rand_bytes)
      end

      private

      def decode_quint(q)
        CHARS.index(q) || raise(Base32Error, "Invalid Base32 Character - '#{q}'")
      end
    end
  end
end
