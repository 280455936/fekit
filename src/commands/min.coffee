syspath = require 'path'
compiler = require "../compiler/compiler"
utils = require "../util"
md5 = require "MD5"
uglifycss = require("uglifycss")
jsp = require("uglify-js").parser;
pro = require("uglify-js").uglify;

exports.usage = "压缩/混淆项目文件"


exports.set_options = ( optimist ) ->

    optimist.alias 'f' , 'filename'
    optimist.describe 'f' , '指定编译某个文件, 而不是当前目录. 处理后默认将文件放在同名目录下并加后缀 min'


process_directory = ( options ) ->


    conf = utils.config.parse( options.cwd )

    conf.each_export_files (srcpath, parents) =>
        utils.logger.log( "正在处理 #{srcpath}" )
        urlconvert = new utils.UrlConvert( srcpath )
        writer = new utils.file.writer()
        source = compiler.compile( srcpath, parents )

        switch urlconvert.extname
            when ".css"
                final_code = uglifycss.processString(source)
            when ".js"
                ast = jsp.parse(source)
                ast = pro.ast_mangle(ast)
                ast = pro.ast_squeeze(ast)
                final_code = pro.gen_code( ast )

        md5code = md5(final_code)
        dest = urlconvert.to_prd( md5code )

        # 生成真正的压缩后的文件
        writer.write( dest , final_code )
        # 生成对应的 ver 文件
        writer.write( urlconvert.to_ver() , md5code )   

        utils.logger.log( "已经处理 #{srcpath}  ==> #{dest}" )

    utils.logger.log("DONE.")


process_single_file = ( options ) ->

    if utils.path.is_absolute_path( options.filename ) 
        srcpath = options.filename
    else
        srcpath = syspath.join( options.cwd , options.filename )

    source = compiler.compile( srcpath )

    extname = syspath.extname( srcpath )

    switch extname
        when ".css"
            final_code = uglifycss.processString(source)
        when ".js"
            ast = jsp.parse(source)
            ast = pro.ast_mangle(ast)
            ast = pro.ast_squeeze(ast)
            final_code = pro.gen_code( ast )

    dest = srcpath.replace( extname , ".min" + extname )

    new utils.file.writer().write( dest , final_code )

    utils.logger.log( "已经处理 #{srcpath}  ==> #{dest}" )

    utils.logger.log("DONE.")


exports.run = ( options ) ->
    
    if options.filename 
        process_single_file( options )
    else
        process_directory( options )
