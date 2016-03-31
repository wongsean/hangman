# hangman

#### 吐槽
+ 找一个恰到好处的词典文件至关重要。
+ 其实前20个词比较难

### 开始游戏
```shell
$ ruby play.rb
```
  

### 主要文件结构
scores.txt  
tree.json  
play.rb  
hangman.rb  
hangman/game.rb  
data/en.txt  

data/en.txt 为词典文件，scores.txt 用于存放提交分，tree.json 用于存放决策树序列化后的json字符串，play.rb, hangman.rb, hangman/game.rb 为代码文件
  

### 算法部分
核心是构建决策树，Hangman::build_decision_tree 用于构建决策树，build_decision_tree 调用build_tree递归构建子树。

首先读取词典文件中所有单词，按单词长度分组，使用单词长度的unknown字符串('*' * word.size)作为键(方便直接查找)
```ruby
tree = words.group_by do |word|
  '*' * word.size
end
```
  
讲26个大写字母chars，每组单词words和belongs_to_key 传入build_tree，在build_tree中会首先查询传入单词组中最有几率猜中的字母，作为树中该节点的值(c)，表示接下来应该猜什么，并把猜过的单词从字母表chars中移除，用剩下没猜过的字母表遮掩words中的每个单词，按相同情况分组作为子树分支
```ruby
reg = Regexp.new("[#{chars.join}]")
tree = words.group_by { |word| word.gsub reg, '*' }
```
  
再在子树tree分支中分别再递归调用本方法构建子树
```ruby
tree.each do |key, value|
  tree[key] = build_tree chars, value, key
end
```
  
最后返回包含子树的此节点
```ruby
{
  :c => optimal_c,
  :t => tree
}
```
  
作为临界条件，当belongs_to_key中不再含有'*'所表示的未知字符，则表示已经猜中，直接返回空 { }
  
因构建时间较长(1min左右)，在play.rb中选择预先构建并序列化为tree.json文件，使用时从文件中加载。
  
### 逻辑部分
逻辑部分构建了一个Game类，实例化时加载tree.json和最高分，调用play方法开始游戏，通过httparty模块方法调用API，并将返回结果存入实例变量中。在猜词过程中错误次数超过10次则错误，返回单词不含'*'则正确，决策树中无对应分支则代表该词不在词典中。  
每次猜完一个词请求一次结果并输出，直到80个词猜完，根据分数是否高于最高分数决定是否提交。
  
### 结语
功能虽然完成，但代码仍有挺多可重构的空间，以增强可维护性和可读性，遗憾于这几天生病，之后自己再慢慢改进把。