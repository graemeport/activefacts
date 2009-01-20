#
# Generate Ruby for the ActiveFacts API from an ActiveFacts vocabulary.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/generate/oo'

module ActiveFacts

  module Generate
    class RUBY < OO

      def set_option(option)
        @sql ||= false
        case option
        when 'help', '?'
          $stderr.puts "Usage:\t\tafgen --ruby[=option,option] input_file.cql\n"+
              "options:\tsql\tEmit data to enable mappings to SQL"
          exit 0
        when 'sql'; @sql = true
        else super
        end
      end

      def vocabulary_start(vocabulary)
        if @sql
          require 'activefacts/persistence'
          @tables = vocabulary.tables
        end
        puts "require 'activefacts/api'\n\n"
        puts "module #{vocabulary.name}\n\n"
      end

      def vocabulary_end
        puts "end"
      end

      def value_type_dump(o)
        return if !o.supertype
        if o.name == o.supertype.name
            # In ActiveFacts, parameterising a ValueType will create a new datatype
            # throw Can't handle parameterized value type of same name as its datatype" if ...
        end

        length = (l = o.length) && l > 0 ? ":length => #{l}" : nil
        scale = (s = o.scale) && s > 0 ? ":scale => #{s}" : nil
        params = [length,scale].compact * ", "

        ruby_type_name =
          case o.supertype.name
            when "VariableLengthText"; "String"
            when "Date"; "::Date"
            else o.supertype.name
          end

        puts "  class #{o.name} < #{ruby_type_name}\n" +
             "    value_type #{params}\n"
        puts "    table" if @sql and @tables.include? o
        puts "    \# REVISIT: #{o.name} has restricted values\n" if o.value_restriction
        puts "    \# REVISIT: #{o.name} is in units of #{o.unit.name}\n" if o.unit
        roles_dump(o)
        puts "  end\n\n"
      end

      def subtype_dump(o, supertypes, pi = nil)
        puts "  class #{o.name} < #{ supertypes[0].name }"
        puts "    identified_by #{identified_by(o, pi)}" if pi
        puts "    table" if @sql and @tables.include? o
        fact_roles_dump(o.fact_type) if o.fact_type
        roles_dump(o)
        puts "  end\n\n"
        @constraints_used[pi] = true if pi
      end

      def non_subtype_dump(o, pi)
        puts "  class #{o.name}"
        puts "    identified_by #{identified_by(o, pi)}"
        puts "    table" if @sql and @tables.include? o
        fact_roles_dump(o.fact_type) if o.fact_type
        roles_dump(o)
        puts "  end\n\n"
        @constraints_used[pi] = true
      end

      # Dump one fact type.
      def fact_type_dump(fact_type, name)
        return if skip_fact_type(fact_type)
        o = fact_type.entity_type

        primary_supertype = o && (o.identifying_supertype || o.supertypes[0])
        secondary_supertypes = o.supertypes-[primary_supertype]

        # Get the preferred identifier, but don't emit it unless it's different from the primary supertype's:
        pi = o.preferred_identifier
        pi = nil if pi && primary_supertype && primary_supertype.preferred_identifier == pi

        puts "  class #{name}" +
          (primary_supertype ? " < "+primary_supertype.name : "") +
          "\n" +
          secondary_supertypes.map{|sst| "    supertype :#{sst.name}"}*"\n" +
          (pi ? "    identified_by #{identified_by(o, pi)}" : "")
        fact_roles_dump(fact_type)
        roles_dump(o)
        puts "  end\n\n"

        @fact_types_dumped[fact_type] = true
      end

      def identified_by_roles_and_facts(entity_type, identifying_roles, identifying_facts, preferred_readings)
        identifying_roles.map{|role|
            ":"+preferred_role_name(role)
          }*", "
      end

      def roles_dump(o)
        @ar_by_role = nil
        if @sql and @tables.include?(o)
          ar = o.absorbed_roles
          @ar_by_role = ar.all_role_ref.inject({}){|h,rr|
            input_role = (j=rr.all_join_path).size > 0 ? j[0].input_role : rr.role
            (h[input_role] ||= []) << rr
            h
          }
          #puts ar.all_role_ref.map{|rr| "\t"+rr.describe}*"\n"
        end
        super
      end

      def unary_dump(role, role_name)
        puts "    maybe :"+role_name
      end

      def role_dump(role)
        other_role = role.fact_type.all_role.select{|r| r != role}[0] || role
        if @ar_by_role and @ar_by_role[other_role] and @sql
          puts "    # role #{role.fact_type.describe(role)}: absorbs in through #{preferred_role_name(other_role)}: "+@ar_by_role[other_role].map(&:column_name)*", "
        end
        super
      end

      def binary_dump(role, role_name, role_player, one_to_one = nil, readings = nil, other_role_name = nil, other_method_name = nil)
        # Find whether we need the name of the other role player, and whether it's defined yet:
        if role_name.camelcase(true) == role_player.name
          # Don't use Class name if implied by rolename
          role_reference = nil
        elsif !@concept_types_dumped[role_player]
          role_reference = '"'+role_player.name+'"'
        else
          role_reference = role_player.name
        end
        other_role_name = ":"+other_role_name if other_role_name

        line = "    #{one_to_one ? "one_to_one" : "has_one" } " +
                [ ":"+role_name,
                  role_reference,
                  readings,
                  other_role_name
                ].compact*", "+"  "
        line += " "*(48-line.length) if line.length < 48
        line += "\# See #{role_player.name}.#{other_method_name}" if other_method_name
        puts line
        puts "    \# REVISIT: #{other_role_name} has restricted values\n" if role.role_value_restriction
      end

    end
  end
end
