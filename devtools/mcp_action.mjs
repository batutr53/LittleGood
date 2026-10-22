import { Client } from '../tools/godot-forge/node_modules/@modelcontextprotocol/sdk/dist/esm/client/index.js';
import { StdioClientTransport } from '../tools/godot-forge/node_modules/@modelcontextprotocol/sdk/dist/esm/client/stdio.js';
import fs from 'node:fs';
const client = new Client({name:'LittleGod development',version:'1.0.0'});
const transport = new StdioClientTransport({command:'C:/Program Files/nodejs/node.exe',args:['D:/LittleGod/tools/godot-forge/dist/index.js','--project','D:/LittleGod','--launch','none']});
try {
 await client.connect(transport);
 const actions = JSON.parse(fs.readFileSync(process.argv[2],'utf8'));
 for (const action of actions) {
  const r = await client.callTool(action);
  for(const c of r.content??[]) if(c.type==='text')console.log(action.name,c.text);else if(c.type==='image' && action.output)fs.writeFileSync(action.output,Buffer.from(c.data,'base64'));
  if(r.isError)process.exitCode=1;
 }
} finally {await client.close();}
