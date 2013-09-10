require 'openssl'
require 'base64'

module MoneyTree
  module Support
    include OpenSSL
    
    INT32_MAX = 256 ** [1].pack("L*").size
    INT64_MAX = 256 ** [1].pack("Q*").size
    BASE58_CHARS = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    
    def int_to_base58(int_val, leading_zero_bytes=0)
      base58_val, base = '', BASE58_CHARS.size
      while int_val > 0
        int_val, remainder = int_val.divmod(base)
        base58_val = BASE58_CHARS[remainder] + base58_val
      end
      base58_val
    end

    def base58_to_int(base58_val)
      int_val, base = 0, BASE58_CHARS.size
      base58_val.reverse.each_char.with_index do |char,index|
        raise ArgumentError, 'Value not a valid Base58 String.' unless char_index = BASE58_CHARS.index(char)
        int_val += char_index*(base**index)
      end
      int_val
    end

    def encode_base58(hex)
      leading_zero_bytes  = (hex.match(/^([0]+)/) ? $1 : '').size / 2
      ("1"*leading_zero_bytes) + int_to_base58( hex.to_i(16) )
    end

    def decode_base58(base58_val)
      s = base58_to_int(base58_val).to_s(16); s = (s.bytesize.odd? ? '0'+s : s)
      s = '' if s == '00'
      leading_zero_bytes = (base58_val.match(/^([1]+)/) ? $1 : '').size
      s = ("00"*leading_zero_bytes) + s  if leading_zero_bytes > 0
      s
    end
    alias_method :base58_to_hex, :decode_base58
    
    def to_serialized_base58(hex)
      hash = sha256 hex
      hash = sha256 hash
      checksum = hash.slice(0..7)
      address = hex + checksum
      encode_base58 address
    end
    
    def digestify(digest_type, source, opts = {})
      source = [source].pack("H*") unless opts[:ascii]
      bytes_to_hex Digest.digest(digest_type, source)
    end
    
    def sha256(source, opts = {})
      digestify('SHA256', source, opts)
    end
    
    def ripemd160(source, opts = {})
      digestify('RIPEMD160', source, opts)
    end
    
    def encode_base64(hex)
      Base64.encode64([hex].pack("H*")).chomp
    end
    
    def decode_base64(base64)
      Base64.decode64(base64).unpack("H*")[0]
    end
    
    def hmac_sha512(key, message)
      digest = Digest::SHA512.new
      HMAC.digest digest, key, message
    end
    
    def hmac_sha512_hex(key, message)
      md = hmac_sha512(key, message)
      md.unpack("H*").first.rjust(64, '0')
    end
    
    def bytes_to_int(bytes, base = 16)
      # bytes = bytes.bytes unless bytes.respond_to?(:inject)
      # bytes.inject {|a, b| (a << 8) + b }
      if bytes.is_a?(Array)
        bytes = bytes.pack("C*")
      end
      bytes.unpack("H*")[0].to_i(16)
    end
    
    def int_to_hex(i)
      hex = i.to_s(16)
      hex = '0' + hex unless (hex.length % 2).zero?
      hex.downcase
    end
        
    def int_to_bytes(i)
      [int_to_hex(i)].pack("H*")
    end
    
    def bytes_to_hex(bytes)
      bytes.unpack("H*")[0].downcase
    end
    
    def hex_to_bytes(hex)
      [hex].pack("H*")
    end
    
    def hex_to_int(hex)
      hex.to_i(16)
    end
  end
end