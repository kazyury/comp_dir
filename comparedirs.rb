#!ruby -Ks

require "fileutils"

# comparedir.rb

class CompareDirs
	def initialize(dir_a , dir_b)
		raise "�w�肳�ꂽ�f�B���N�g��#{dir_a}�����݂��܂���B" unless File.exist?(dir_a)
		raise "�w�肳�ꂽ�f�B���N�g��#{dir_b}�����݂��܂���B" unless File.exist?(dir_b)
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
		puts  "L1) #{result.dir_a} �ɂ̂ݑ��݂���t�@�C�������X�g. (�ΏہF#{result.a_but_b.size}��)"
		puts  "L2) #{result.dir_b} �ɂ̂ݑ��݂���t�@�C�������X�g. (�ΏہF#{result.b_but_a.size}��)"
		puts  "LD) ����ɂ����݂��邪�A���ق̑��݂��Ă���t�@�C�������X�g. (�ΏہF#{result.differences.size}��)"
		puts  ""
		puts  "F1) #{result.dir_a} �ɂ̂ݑ��݂���t�@�C�������t�@�C���o�� (�o�̓t�@�C�����F#{File.basename(result.dir_a)}_only.txt)"
		puts  "F2) #{result.dir_b} �ɂ̂ݑ��݂���t�@�C�������t�@�C���o�� (�o�̓t�@�C�����F#{File.basename(result.dir_b)}_only.txt)"
		puts  "FD) ���e�ɍ��ق̑��݂��Ă���t�@�C�������X�g. (�o�̓t�@�C�����F#{File.basename(result.dir_a)}-#{File.basename(result.dir_b)}_differ.txt)"
		puts  ""
		puts  "D)  diff�R�}���h�����s"
		puts  "DF) diff�R�}���h�̌��ʂ��t�@�C���o��(�o�̓t�@�C����:*.diff.txt)"
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

