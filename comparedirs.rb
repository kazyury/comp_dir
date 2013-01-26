#!ruby -Ks

require "fileutils"

# comparedir.rb

class CompareDirs
	def initialize(dir_a , dir_b)
		raise "指定されたディレクトリ#{dir_a}が存在しません。" unless File.exist?(dir_a)
		raise "指定されたディレクトリ#{dir_b}が存在しません。" unless File.exist?(dir_b)
		@dir_a=dir_a
		@dir_b=dir_b
		@dir_a_entries=[]
		@dir_b_entries=[]
		traverse(@dir_a_entries,dir_a)
		traverse(@dir_b_entries,dir_b)
		@dir_a_entries.collect!{|item| item.sub!(Regexp.new(Regexp.escape(dir_a)) , '') }
		@dir_b_entries.collect!{|item| item.sub!(Regexp.new(Regexp.escape(dir_b)) , '') }

		@a_but_b=@dir_a_entries - @dir_b_entries
		@b_but_a=@dir_b_entries - @dir_a_entries
		@a_also_b=@dir_a_entries & @dir_b_entries

		@differences=[]
		@a_also_b.each{|file|
			contents_a=File.open("#{@dir_a}/#{file}",'rb'){|f| f.read }
			contents_b=File.open("#{@dir_b}/#{file}",'rb'){|f| f.read }
			@differences.push file unless contents_a == contents_b
		}
	end
	attr_reader :dir_a , :dir_b , :a_but_b , :b_but_a ,:differences

	def differs(&block)
		@differences.each{|item| yield @dir_a+item , @dir_b+item}
	end

	:private
	def traverse(stuck,dir)
		Dir.entries(dir).sort.each{|f|
			next if f=="." or f==".."
			f=dir+"/"+f
			if File.directory?(f)
				traverse(stuck,f) 
			else
				stuck.push f
			end
		}
	end
end

if __FILE__ == $0
	def usage
		warn ""
		warn "usage :"
		warn "\t#{$0} dir1 dir2"
		warn ""
		exit
	end

	def menu(result)
		puts  "\n----------------- SELECT FROM HERE ----------------------"
		puts  "L1) #{result.dir_a} にのみ存在するファイルをリスト. (対象：#{result.a_but_b.size}件)"
		puts  "L2) #{result.dir_b} にのみ存在するファイルをリスト. (対象：#{result.b_but_a.size}件)"
		puts  "LD) 何れにも存在するが、差異の存在しているファイルをリスト. (対象：#{result.differences.size}件)"
		puts  ""
		puts  "F1) #{result.dir_a} にのみ存在するファイル名をファイル出力 (出力ファイル名：#{File.basename(result.dir_a)}_only.txt)"
		puts  "F2) #{result.dir_b} にのみ存在するファイル名をファイル出力 (出力ファイル名：#{File.basename(result.dir_b)}_only.txt)"
		puts  "FD) 内容に差異の存在しているファイルをリスト. (出力ファイル名：#{File.basename(result.dir_a)}-#{File.basename(result.dir_b)}_differ.txt)"
		puts  ""
		puts  "D)  diffコマンドを実行"
		puts  "DF) diffコマンドの結果をファイル出力(出力ファイル名:*.diff.txt)"
		puts  ""
		puts  "q)  quit"
		puts  ""
		print "----------->"
	end

	usage unless ARGV.size==2
	result=CompareDirs.new(ARGV[0],ARGV[1])
	while true
		menu(result)
		operation=STDIN.gets.chomp
		case operation
		when "L1"
			puts result.a_but_b.join("\n")
		when "L2"
			puts result.b_but_a.join("\n")
		when "LD"
			puts result.differences.join("\n")
		when "F1"
			File.open("#{File.basename(result.dir_a)}_only.txt","w"){|f| f.puts result.a_but_b.join("\n") }
		when "F2"
			File.open("#{File.basename(result.dir_b)}_only.txt","w"){|f| f.puts result.b_but_a.join("\n") }
		when "FD"
			File.open("#{File.basename(result.dir_a)}-#{File.basename(result.dir_b)}_differ.txt","w"){|f| f.puts result.differences.join("\n") }
			puts result.differences.join("\n")
		when "D"
			result.differs{|a,b| 
				out=`diff -wc #{a} #{b}`
				puts out
			}
		when "DF"
			result.differs{|a,b| 
				out=`diff -wc #{a} #{b}`
				File.open("#{File.basename(a)}.diff.txt","w"){|f| f.puts out }
			}

		when "q"
			break
		end
	end
end

