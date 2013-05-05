class Innodb::Page::SysDataDictionaryHeader < Innodb::Page
  # The position of the data dictionary header within the page.
  def pos_data_dictionary_header
    pos_fil_header + size_fil_header
  end

  # The size of the data dictionary header.
  def size_data_dictionary_header
    ((8 * 3) + (4 * 7) + 4 + Innodb::FsegEntry::SIZE)
  end

  # Parse the data dictionary header from the page.
  def data_dictionary_header
    cursor(pos_data_dictionary_header).name("data_dictionary_header") do |c|
      {
        :max_row_id => c.name("max_row_id") { c.get_uint64 },
        :max_table_id => c.name("max_table_id") { c.get_uint64 },
        :max_index_id => c.name("max_index_id") { c.get_uint64 },
        :max_space_id => c.name("max_space_id") { c.get_uint32 },
        :unused_mix_id_low => c.name("unused_mix_id_low") { c.get_uint32 },
        :indexes => c.name("indexes") {{
          :SYS_TABLES => c.name("SYS_TABLES") {{
            :PRIMARY => c.name("PRIMARY") { c.get_uint32 },
            :ID      => c.name("ID")      { c.get_uint32 }, 
          }},
          :SYS_COLUMNS => c.name("SYS_COLUMNS") {{
            :PRIMARY => c.name("PRIMARY") { c.get_uint32 },
          }},
          :SYS_INDEXES => c.name("SYS_INDEXES") {{
            :PRIMARY => c.name("PRIMARY") { c.get_uint32 },
          }},
          :SYS_FIELDS => c.name("SYS_FIELDS") {{
            :PRIMARY => c.name("PRIMARY") { c.get_uint32 },
          }}
        }},
        :unused_space => c.name("unused_space") { c.get_bytes(4) },
        :fseg => c.name("fseg") { Innodb::FsegEntry.get_inode(@space, c) },
      }
    end
  end

  def dump
    super

    puts
    puts "data_dictionary header:"
    pp data_dictionary_header
  end

  # A record describer for SYS_TABLES clustered records.
  # This will be useless until redundant format indexes are supported.
  class SYS_TABLES_PRIMARY
    def self.cursor_sendable_description(page)
      {
        :type => :clustered,
        :key => [
          ["VARCHAR(100)", :NOT_NULL],  # NAME
        ],
        :row => [
          ["VARCHAR(100)", :NOT_NULL], # ID
          [:INT, :NOT_NULL], # N_COLS
          [:INT, :NOT_NULL], # TYPE
          ["VARCHAR(100)", :NOT_NULL], # MIX_ID
          [:INT, :NOT_NULL], # MIX_LEN
          ["VARCHAR(100)", :NOT_NULL], # CLUSTER_NAME
          [:INT, :NOT_NULL], # SPACE
        ]
      }
    end
  end

  RECORD_DESCRIBERS = {
    :SYS_TABLES  => { :PRIMARY => SYS_TABLES_PRIMARY, :ID => nil },
    :SYS_COLUMNS => { :PRIMARY => nil },
    :SYS_INDEXES => { :PRIMARY => nil },
    :SYS_FIELDS  => { :PRIMARY => nil },
  }
end
