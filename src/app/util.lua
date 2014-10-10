--
-- Author: yjun
-- Date: 2014-09-24 11:02:00
--
function loadCsvFile(filePath) 
    -- 读取文件
    local data = io.readfile(filePath)
    print(data)
    -- 按行划分
    local lineStr = string.split(data, '\n')
    --[[
		从第3行开始保存（第一行是标题，第二行是注释，后面的行才是内容） 
		
		用二维数组保存：arr[ID][属性标题字符串]
	]]--
	local titles = string.split(lineStr[1], ',')
	local arrs = {};
	for i = 3, #lineStr, 1 do
	    -- 一行中，每一列的内容
	    local content = string.split(lineStr[i], ',');

	    -- 以标题作为索引，保存每一列的内容，取值的时候这样取：arrs[ID].Title
	    arrs[content[1]] = {};
	    for j = 1, #titles, 1 do
	    	arrs[content[1]][titles[j]] = content[j];
	    end
	end
	return arrs;
end