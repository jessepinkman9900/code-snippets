'use client';

import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { CardAction } from "./ui/card";
import { Label } from "./ui/label";
import { Input } from "./ui/input";
import { useRef, useState } from "react";
import { createPublicClient, http, PublicClient } from 'viem'
import { CheckIcon, XIcon } from "lucide-react";
import { Table, TableBody, TableCaption, TableCell, TableHead, TableHeader, TableRow } from "./ui/table";

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

interface RpcCheckResult {
  id: string;
  valid: boolean;
  requests: RpcMethodCheckResult[];
}

interface RpcMethodCheckResult {
  id: string;
  valid: boolean;
  payload: string;
  response: string;
}

function isValidHttpsUrl(url: string): boolean {
  try {
    const urlObj = new URL(url);
    return urlObj.protocol === 'https:';
  } catch {
    return false;
  }
}

export default function RpcChecker() {
  const formRef = useRef<HTMLFormElement>(null);
  const [rpcUrl, setRpcUrl] = useState<string>("");
  const [isChecking, setIsChecking] = useState<boolean>(false);
  const [checkResult, setCheckResult] = useState<RpcCheckResult | null>(null);
  const [urlError, setUrlError] = useState<string>("");
  
  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
  
    const formData = new FormData(e.currentTarget);
    const rpc = formData.get("rpc-url") as string;
  
    // validate
    if (!rpc) {
      setUrlError("rpc is required");
      return;
    }

    if (!isValidHttpsUrl(rpc)) {
      setUrlError("rpc must be a https url");
      return;
    }

    setUrlError("");
    setIsChecking(true);
    setRpcUrl(rpc);
    
    console.log(`Checking rpc: ${rpc}`);
    const result = await runRpcChecks(rpc);

    setIsChecking(false);
    setCheckResult(result);
  }

  return (
    <Card className="@container/card">
      <CardHeader>
        <CardTitle>rpc checker</CardTitle>
        <CardDescription>
          Check if an evm rpc endpoint is valid
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form ref={formRef} onSubmit={handleSubmit}>
          <div className="flex flex-col gap-6">
            <div className="grid gap-2">
              <Label htmlFor="rpc">rpc endpoint</Label>
              <Input
                id="rpc"
                name="rpc-url"
                type="text"
                placeholder="https://canto.neobase.one"
                required
                onChange={() => urlError && setUrlError("")}
                className={urlError ? "border-red-500": ""}
              />
            </div>
          </div>
        </form>
      </CardContent>
      <CardFooter>
        <CardAction>
          <Button 
            type="submit"
            onClick={() => formRef.current?.requestSubmit()}
            disabled={isChecking}
          >
            {isChecking ? "Checking..." : "Check"}
          </Button>
        </CardAction>
      </CardFooter>
      {checkResult && (
        <CardFooter>
          <CardContent>
            {checkResult.valid ? <CheckIcon>All checks passed</CheckIcon> : <XIcon>Some checks failed</XIcon>}
            <Table>
              <TableCaption>RPC Checks</TableCaption>
              <TableHeader>
                <TableRow>
                  <TableHead>Valid</TableHead>
                  <TableHead>Method</TableHead>
                  <TableHead>Response</TableHead>
                  <TableHead>Payload</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {checkResult.requests.map((request) => (
                  <TableRow key={request.id}>
                    <TableCell>{request.valid ? <CheckIcon /> : <XIcon />}</TableCell>
                    <TableCell>{request.id}</TableCell>
                    <TableCell>{request.response}</TableCell>
                    <TableCell>{request.payload}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </CardFooter>
      )}
    </Card>
  );
}

async function runRpcChecks(rpc: string): Promise<RpcCheckResult> {
  // create viem client
  const client = createPublicClient({
    transport: http(rpc),
  });

  const eth_chainId = await run_eth_chainId(client);
  const eth_blockNumber = await run_eth_blockNumber(client);
  const eth_getBlockByNumber = await run_eth_getBlockByNumber(client, BigInt(eth_blockNumber.response));

  // accumulate results
  const results: RpcMethodCheckResult[] = [];
  results.push(eth_chainId);
  results.push(eth_blockNumber);
  results.push(eth_getBlockByNumber);

  // 
  const valid = results.every((result) => result.valid);
  
  return {
    id: "rpc-checker",
    valid: valid,
    requests: results
  };
}

async function run_eth_chainId(client: PublicClient): Promise<RpcMethodCheckResult> {
  const response = await client.getChainId();
  console.log(`eth_chainId: ${response}`);
  return {
    id: "eth_chainId",
    valid: true,
    payload: "",
    response: response.toString()
  };
}

async function run_eth_blockNumber(client: PublicClient): Promise<RpcMethodCheckResult> {
  const response = await client.getBlockNumber();
  console.log(`eth_blockNumber: ${response}`);
  return {
    id: "eth_blockNumber",
    valid: true,
    payload: "",
    response: response.toString()
  };
}

async function run_eth_getBlockByNumber(client: PublicClient, blockNumber: bigint): Promise<RpcMethodCheckResult> {
  const response = await client.getBlock({
    blockNumber: blockNumber
  });
  console.log(`eth_getBlockByNumber: ${response.toString()}`);
  return {
    id: "eth_getBlockByNumber",
    valid: true,
    payload: "",
    response: response.toString()
  };
}
