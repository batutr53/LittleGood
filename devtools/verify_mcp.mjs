import { Client } from '../tools/godot-forge/node_modules/@modelcontextprotocol/sdk/dist/esm/client/index.js';
import { StdioClientTransport } from '../tools/godot-forge/node_modules/@modelcontextprotocol/sdk/dist/esm/client/stdio.js';
import fs from 'node:fs';
const client = new Client({name:'LittleGod verification',version:'1.0.0'});
const transport = new StdioClientTransport({command:'C:/Program Files/nodejs/node.exe',args:['D:/LittleGod/tools/godot-forge/dist/index.js','--project','D:/LittleGod','--godot','D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64.exe','--launch','none']});
const log=[];
async function call(name,args){const r=await client.callTool({name,arguments:args}); const text=r.content?.filter(c=>c.type==='text').map(c=>c.text).join('\n');console.log(name,JSON.stringify(args),text?.slice(0,2200));log.push({name,args,result:text,error:r.isError}); if(r.isError)throw Error(text);return r;}
try {
 await client.connect(transport);
 console.log('MCP tools:',(await client.listTools()).tools.length);
 await call('project',{action:'info'});
 await call('scene',{action:'open',path:'res://scenes/main.tscn'});
 await call('scene',{action:'tree',depth:2});
 // Probe is created below and removed after verification.
 await call('node',{action:'add',type:'Node2D',name:'MCPProbe'});
 await call('node',{action:'set',path:'MCPProbe',props:{position:[123,45]}});
 await call('node',{action:'get',path:'MCPProbe'});
 await call('node',{action:'delete',path:'MCPProbe'});
 await call('run',{action:'play',mute:true});
 await call('game',{action:'info'});
 await call('run',{action:'errors'});
} finally {fs.writeFileSync('D:/LittleGod/builds/mcp-verification.json',JSON.stringify(log,null,2));await client.close();}
