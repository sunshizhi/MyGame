<?php
/**
 * This file is part of workerman.
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the MIT-LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @author walkor<walkor@workerman.net>
 * @copyright walkor<walkor@workerman.net>
 * @link http://www.workerman.net/
 * @license http://www.opensource.org/licenses/mit-license.php MIT License
 */

/**
 * 用于检测业务代码死循环或者长时间阻塞等问题
 * 如果发现业务卡死，可以将下面declare打开（去掉//注释），并执行php start.php reload
 * 然后观察一段时间workerman.log看是否有process_timeout异常
 */
//declare(ticks=1);

/**
 * 聊天主逻辑
 * 主要是处理 onMessage onClose 
 */
use \GatewayWorker\Lib\Gateway;
use \GatewayWorker\Lib\Db;

class Events
{
   /**
    * 有消息时
    * @param int $client_id
    * @param mixed $message
    */
   public static function onMessage($client_id, $message)
   {
        // debug
        echo "client:{$_SERVER['REMOTE_ADDR']}:{$_SERVER['REMOTE_PORT']} gateway:{$_SERVER['GATEWAY_ADDR']}:{$_SERVER['GATEWAY_PORT']}  client_id:$client_id session:".json_encode($_SESSION)." onMessage:".$message."\n";
        
        // 客户端传递的是json数据
        $message_data = json_decode($message, true);
        if(!$message_data)
        {
            return ;
        }
		
		$db1 = Db::instance('db1');
        
        // 根据类型执行不同的业务
        switch($message_data['type'])
        {
            // 客户端回应服务端的心跳
            case 'pong':
                return;
            // 客户端登录 message格式: {type:login, name:xx, room_id:1} ，添加到客户端，广播给所有客户端xx进入聊天室
            case 'login':
                // 判断是否有房间号
                if(!isset($message_data['room_id']))
                {
                    throw new \Exception("\$message_data['room_id'] not set. client_ip:{$_SERVER['REMOTE_ADDR']} \$message:$message");
                }
                
                // 把房间号昵称放到session中
                $room_id = $message_data['room_id'];
                $client_name = htmlspecialchars($message_data['client_name']);
                $_SESSION['room_id'] = $room_id;
                $_SESSION['client_name'] = $client_name;
              
                // 获取房间内所有用户列表 
                $clients_list = Gateway::getClientSessionsByGroup($room_id);
				
                foreach($clients_list as $tmp_client_id=>$item)
                {
                    $clients_list[$tmp_client_id] = $item['client_name'];
                }
                $clients_list[$client_id] = $client_name;
                
                // 转播给当前房间的所有客户端，xx进入聊天室 message {type:login, client_id:xx, name:xx} 
                $new_message = array('type'=>$message_data['type'], 'client_id'=>$client_id, 'client_name'=>htmlspecialchars($client_name), 'time'=>date('Y-m-d H:i:s'));
                Gateway::sendToGroup($room_id, json_encode($new_message));
                Gateway::joinGroup($client_id, $room_id);
               
                // 给当前用户发送用户列表 
                $new_message['client_list'] = $clients_list;
                Gateway::sendToCurrentClient(json_encode($new_message));
                return;
				
			// 谁先出牌 message: {type:whoStart}
            case 'whoStart':
				// 非法请求
                if(!isset($_SESSION['room_id']))
                {
                    throw new \Exception("\$_SESSION['room_id'] not set. client_ip:{$_SERVER['REMOTE_ADDR']}");
                }
				
                $room_id = $_SESSION['room_id'];
				$client_name = $_SESSION['client_name'];
				
				// 获取房间内所有用户列表 
                $clients_list = Gateway::getClientSessionsByGroup($room_id);
				
				// 删除
				$sql = "DELETE FROM `fightInfo` WHERE room_id=" . $room_id;
				$db1->query($sql);
					
				$tmp_num = 0;
				if(count($clients_list) > 0) {	
					$tmp_num = rand(1, 2);
				}
				$index = 0;
				$who_start = "";	//谁先开始
				$whose_turn = 0;
                foreach($clients_list as $tmp_client_id=>$item)
                {
					++$index;
					if($index == $tmp_num) {
						$who_start = $tmp_client_id;
						$whose_turn = 1;
					} else {
						$whose_turn = 0;
					}
					$tmp = "'" . $tmp_client_id . "'";
					//每个玩家的回合胜利次数，初始为0
					//每个玩家卡牌初始值10
					
					// 删除
					$sql = "DELETE FROM `fightInfo` WHERE u_id=" . $tmp;
					$db1->query($sql);
					
					
					$insert_id = $db1->insert('fightInfo')->cols(array('room_id'=>$room_id, 'u_id'=>$tmp_client_id, 'u_name'=>$item['client_name'], 'state'=>1, 'jewel_num'=>2, 'cards_num' =>10, 'win_round_num'=>0, 'total_score'=>0, 'whose_turn'=>$whose_turn, 'round'=>1))->query();
                }				
				
				$new_message = array(
                    'type'=>'whoStart', 
                    'who_start'=>$who_start,
                    'to_client_id'=>'all',
                    'time'=>date('Y-m-d H:i:s'),
                );
				return Gateway::sendToGroup($room_id ,json_encode($new_message));
                
            // 客户端出牌 message: {type:putCard, to_client_id:xx, content:xx}
            case 'putCard':
                // 非法请求
                if(!isset($_SESSION['room_id']))
                {
                    throw new \Exception("\$_SESSION['room_id'] not set. client_ip:{$_SERVER['REMOTE_ADDR']}");
                }
				
				$other_playerId = self::getOtherPlayerId($client_id);
				$other_ret = $db1->select('*')->from('fightInfo')->where('u_id= :uid')->bindValues(array('uid'=>$other_playerId))->row();
				$ret = $db1->select('*')->from('fightInfo')->where('u_id= :uid')->bindValues(array('uid'=>$client_id))->row();
				
				$whose_turn = $ret['whose_turn'];
				if($whose_turn == 1) {
					$db1->update('fightInfo')->cols(array('whose_turn'))->where('u_id= :uid')->bindValue('whose_turn', 0)->bindValues(array('uid'=>$client_id))->query();
				} else {
					throw new Exception('还没轮到你出牌！');
				}
				
				//不管是否到a出牌还是没到，都将b设置为下次出牌
				$db1->update('fightInfo')->cols(array('whose_turn'))->where('u_id= :uid')->bindValue('whose_turn', 1)->bindValues(array('uid'=>$other_playerId))->query();
				
				$cards_num = $ret['cards_num'];
				if($cards_num > 1) {
					--$cards_num;
					$db1->update('fightInfo')->cols(array('cards_num'))->where('u_id= :uid')->bindValue('cards_num', $cards_num)->bindValues(array('uid'=>$client_id))->query();
				} else {
					throw new Exception('no cards！');
				}
				
                $room_id = $_SESSION['room_id'];
                $client_name = $_SESSION['client_name'];
                $cardType = $message_data['cardType'];
                $cardPower = $message_data['cardPower'];
                // 私聊
                if($message_data['to_client_id'] != 'all')
                {
                    $new_message = array(
                        'type'=>'putCard',
                        'from_client_id'=>$client_id, 
                        'from_client_name' =>$client_name,
                        'cardType' =>$cardType,
                        'cardPower' =>$cardPower,
                        'to_client_id'=>$message_data['to_client_id'],
                        'content'=>"<b>对你说: </b>".nl2br(htmlspecialchars($message_data['content'])),
                        'time'=>date('Y-m-d H:i:s'),
                    );
                    Gateway::sendToClient($message_data['to_client_id'], json_encode($new_message));
                    $new_message['content'] = "<b>你对".htmlspecialchars($message_data['to_client_name'])."说: </b>".nl2br(htmlspecialchars($message_data['content']));
                    return Gateway::sendToCurrentClient(json_encode($new_message));
                }
                
                $new_message = array(
                    'type'=>'putCard', 
                    'from_client_id'=>$client_id,
                    'from_client_name' =>$client_name,
                    'to_client_id'=>'all',
                    'cardType' =>$cardType,
                    'cardPower' =>$cardPower,
                    'content'=>nl2br(htmlspecialchars($message_data['content'])),
                    'time'=>date('Y-m-d H:i:s'),
					'whose_turn' => $other_playerId,
                );
				
                return Gateway::sendToGroup($room_id ,json_encode($new_message));
			
			//放弃该回合
			case 'giveUp':
                // 非法请求
                if(!isset($_SESSION['room_id']))
                {
                    throw new \Exception("\$_SESSION['room_id'] not set. client_ip:{$_SERVER['REMOTE_ADDR']}");
                }
				
                $room_id = $_SESSION['room_id'];
                $client_name = $_SESSION['client_name'];
				
				$m_totalCardNum = $message_data['m_totalCardNum'];	//我的总分
				$o_totalCardNum = $message_data['o_totalCardNum'];	//对手的总分
				$mySelf_jewel = $message_data['mySelf_jewel'];		//我的宝石数量
				$other_jewel = $message_data['other_jewel'];		//对手的宝石数量
				$mySelf_jewel = (int)$mySelf_jewel;
				$other_jewel = (int)$other_jewel;
				
				$winer = 0;
				$winer_round_id = 0;
				
				//状态变为弃权
				$ret = $db1->select('*')->from('fightInfo')->where('u_id= :uid')->bindValues(array('uid'=>$client_id))->row();
				$db1->update('fightInfo')->cols(array('state'))->where('u_id= :uid')->bindValue('state', 0)->bindValues(array('uid'=>$client_id))->query();
				$round = $ret['round'];	//第几回合
				echo "round:" . $round;
				
				$other_playerId = self::getOtherPlayerId($client_id);
				$other_ret = $db1->select('*')->from('fightInfo')->where('u_id= :uid')->bindValues(array('uid'=>$other_playerId))->row();
				$ret = $db1->select('*')->from('fightInfo')->where('u_id= :uid')->bindValues(array('uid'=>$client_id))->row();
				$other_state = $other_ret['state'];
				$other_cards_num = $other_ret['cards_num'];
				
				//a弃权，先判断b是否还有牌，没牌了，即结算；有牌的话，在判断b的状态是不是弃权状态，弃权状态的话，根据当前回合结算回合或者游戏；有卡牌的话且没有弃权让b继续出牌。
				if($other_cards_num == 0) {	//b没卡牌了
					if(((int)$m_totalCardNum == (int)$o_totalCardNum)) {	//分数相等
						$winer = self::getWiner($mySelf_jewel, $other_jewel, $client_id);
					} else {
						if((int)$m_totalCardNum > (int)$o_totalCardNum) {
							--$other_jewel;
							
						} else {
							--$mySelf_jewel;
						}
						$winer = self::getWiner($mySelf_jewel, $other_jewel, $client_id);
					}
				} else {	//b还有卡牌
					if($other_state == 0) {	//b弃权
						if(((int)$m_totalCardNum == (int)$o_totalCardNum)) {	//分数相等
							$winer_round_id = self::getWiner($mySelf_jewel, $other_jewel, $client_id);
						} else {
							if((int)$m_totalCardNum > (int)$o_totalCardNum) {
								--$other_jewel;
							} else {
								--$mySelf_jewel;
							}
							$winer_round_id = self::getWiner($mySelf_jewel, $other_jewel, $client_id);
						}
						
						//给胜利者加上回合胜利次数
						$winer_ret = $db1->select('*')->from('fightInfo')->where('u_id= :uid')->bindValues(array('uid'=>$winer_round_id))->row();
						$win_round_num = $winer_ret['win_round_num'];
						++$win_round_num;
						$db1->update('fightInfo')->cols(array('win_round_num'))->where('u_id= :uid')->bindValue('win_round_num', $win_round_num)->bindValues(array('uid'=>$winer_round_id))->query();
						
						if($round == 3) {	//最后一个回合
							$winer = $winer_round_id;
							self::updateRound($client_id, $other_playerId, 0);
						} 
						elseif($round == 2) {	//第二个回合
							$other_ret = $db1->select('*')->from('fightInfo')->where('u_id= :uid')->bindValues(array('uid'=>$other_playerId))->row();
							$ret = $db1->select('*')->from('fightInfo')->where('u_id= :uid')->bindValues(array('uid'=>$client_id))->row();
							$other_win_round_num = $other_ret['win_round_num'];
							$ret_win_round_num = $ret['win_round_num'];
							
							if($ret_win_round_num == 2) {
								$winer = $client_id;
							}
							elseif($other_win_round_num == 2) {
								$winer = $other_playerId;
							} else {
								self::updateRound($client_id, $other_playerId, 3);
							}
						} else {	//第一个回合
							self::updateRound($client_id, $other_playerId, 2);
						}
					} else {
						
					}
				}
                $new_message = array(
                    'type'=>'giveUp', 
                    'from_client_id'=>$client_id,
                    'to_client_id'=>'all',
                    'winer' =>$winer,				//最终胜利者
                    'winer_round' =>$winer_round_id,	//回合胜利者
                    'round' =>$round,
                    'time'=>date('Y-m-d H:i:s'),
                );
                return Gateway::sendToGroup($room_id ,json_encode($new_message));
				
			// 结束游戏 message: {type:gameOver, to_client_id:xx, content:xx}
            case 'gameOver':
				// 非法请求
                if(!isset($_SESSION['room_id']))
                {
                    throw new \Exception("\$_SESSION['room_id'] not set. client_ip:{$_SERVER['REMOTE_ADDR']}");
                }
                $room_id = $_SESSION['room_id'];
                $ntype = $message_data['ntype'];
				$winer = 0;
				$loser = "";
				
				if($ntype == "1") {	//没有卡牌了
					$m_totalCardNum = $message_data['m_totalCardNum'];	//我的总分
					$o_totalCardNum = $message_data['o_totalCardNum'];	//对手的总分
					$mySelf_jewel = $message_data['mySelf_jewel'];		//我的宝石数量
					$other_jewel = $message_data['other_jewel'];		//对手的宝石数量
					$mySelf_jewel = (int)$mySelf_jewel;
					$other_jewel = (int)$other_jewel;
					
					if(((int)$m_totalCardNum == (int)$o_totalCardNum)) {	//分数相等
						$winer = self::getWiner($mySelf_jewel, $other_jewel, $client_id);
					} else {
						if((int)$m_totalCardNum > (int)$o_totalCardNum) {
							++$mySelf_jewel;
							
						} else {
							++$other_jewel;
						}
						$winer = self::getWiner($mySelf_jewel, $other_jewel, $client_id);
					}
				}
				elseif($ntype == "2") {	//放弃
					$loser = $client_id;
				}
				
				$new_message = array(
                    'type'=>'gameOver', 
					'ntype'=>$ntype,
                    'from_client_id'=>$client_id,
                    'to_client_id'=>'all',
                    'loser' =>$loser,
                    'winer' =>$winer,
                    'time'=>date('Y-m-d H:i:s'),
                );
				return Gateway::sendToGroup($room_id ,json_encode($new_message));
        }
   }
   
   /**
    * 当客户端断开连接时
    * @param integer $client_id 客户端id
    */
   public static function onClose($client_id)
   {
       // debug
       echo "client:{$_SERVER['REMOTE_ADDR']}:{$_SERVER['REMOTE_PORT']} gateway:{$_SERVER['GATEWAY_ADDR']}:{$_SERVER['GATEWAY_PORT']}  client_id:$client_id onClose:''\n";
       
       // 从房间的客户端列表中删除
       if(isset($_SESSION['room_id']))
       {
           $room_id = $_SESSION['room_id'];
           $new_message = array('type'=>'logout', 'from_client_id'=>$client_id, 'from_client_name'=>$_SESSION['client_name'], 'time'=>date('Y-m-d H:i:s'));
           Gateway::sendToGroup($room_id, json_encode($new_message));
       }
   }
  
	//获取胜利者，$mySelf 自己的宝石数 $other 对手的宝石数
	public static function getWiner($mySelf, $other, $client_id) {
		$winer = 0;
		if($mySelf == $other) {
			$winer = 0;
		} else {
			if($mySelf > $other) {
				$winer = $client_id;
			} else {
				$winer = self::getOtherPlayerId($client_id);
			}
		}
		return $winer;
	}
	
	//获取对手id
	public static function getOtherPlayerId($client_id) {
		// 获取房间内所有用户列表 
		$room_id = $_SESSION['room_id'];
        $clients_list = Gateway::getClientSessionsByGroup($room_id);
		$otherPlayerId = "";
		foreach($clients_list as $tmp_client_id=>$item)
		{
			if($tmp_client_id != $client_id) {
				$otherPlayerId = $tmp_client_id;
				return $otherPlayerId;
			}
		}
	}
	
	//更新回合
	public static function updateRound($client_id, $other_playerId, $round) {
		$db1 = Db::instance('db1');
		$db1->update('fightInfo')->cols(array('round'))->where('u_id= :uid')->bindValue('round', $round)->bindValues(array('uid'=>$client_id))->query();
		$db1->update('fightInfo')->cols(array('round'))->where('u_id= :uid')->bindValue('round', $round)->bindValues(array('uid'=>$other_playerId))->query();
	}
	
	//更新状态
	public static function updateRound($client_id, $other_playerId, $round) {
		$db1 = Db::instance('db1');
		$db1->update('fightInfo')->cols(array('round'))->where('u_id= :uid')->bindValue('round', $round)->bindValues(array('uid'=>$client_id))->query();
		$db1->update('fightInfo')->cols(array('round'))->where('u_id= :uid')->bindValue('round', $round)->bindValues(array('uid'=>$other_playerId))->query();
	}
}
