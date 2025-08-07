import React, { useState, useEffect, useRef } from 'react';
import { Layout, Input, List, Typography, Spin, Card, Tag } from 'antd';
import { RobotOutlined, SendOutlined } from '@ant-design/icons';
import './App.css'; // Assume some basic styling

const { Header, Content, Sider } = Layout;
const { Title } = Typography;

function App() {
  const [messages, setMessages] = useState([]);
  const [inputValue, setInputValue] = useState('');
  const [socket, setSocket] = useState(null);
  const [isThinking, setIsThinking] = useState(false);

  useEffect(() => {
    // Connect to the backend WebSocket
    const ws = new WebSocket('ws://localhost:8000/ws');
    setSocket(ws);

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      setMessages(prev => [...prev, data]);
      if (data.type === 'thought' || data.type === 'action') {
        setIsThinking(true);
      } else {
        setIsThinking(false);
      }
    };

    return () => ws.close();
  }, []);

  const handleSend = () => {
    if (inputValue.trim() && socket) {
      const taskMessage = { type: 'user_task', content: inputValue };
      socket.send(JSON.stringify(taskMessage));
      setMessages(prev => [...prev, taskMessage]);
      setInputValue('');
      setIsThinking(true);
    }
  };

  const renderMessage = (item) => {
    let color = 'blue';
    let icon = null;
    let content = item.content;

    switch(item.type) {
      case 'user_task': color = 'cyan'; break;
      case 'thought': color = 'geekblue'; content = `Thinking: ${item.content}`; break;
      case 'action': color = 'purple'; content = `Action: ${item.tool}(${JSON.stringify(item.args)})`; break;
      case 'result': color = 'green'; content = `Result: ${item.content}`; break;
      case 'error': color = 'red'; content = `Error: ${item.content}`; break;
    }
    return <List.Item><Tag color={color} style={{whiteSpace: 'pre-wrap'}}>{content}</Tag></List.Item>
  }

  return (
    <Layout style={{ height: '100vh' }}>
      <Header style={{ color: 'white' }}><RobotOutlined /> Vibe Agent 2.5</Header>
      <Layout>
        <Sider width={500} theme="light" style={{ padding: '12px', display: 'flex', flexDirection: 'column' }}>
          <Title level={4}>Conversation</Title>
          <List
            dataSource={messages}
            renderItem={renderMessage}
            style={{ flex: 1, overflowY: 'auto', marginBottom: '12px' }}
          />
          {isThinking && <Spin tip="Agent is working..." style={{marginBottom: '10px'}}/>}
          <Input
            placeholder="Tell the agent what to do..."
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onPressEnter={handleSend}
            suffix={<SendOutlined onClick={handleSend} />}
          />
        </Sider>
        <Content>
          <iframe
            src="http://localhost:7900/?autoconnect=true&password=pw"
            style={{ width: '100%', height: '100%', border: 'none' }}
            title="Agent Browser"
          />
        </Content>
      </Layout>
    </Layout>
  );
}

export default App;
