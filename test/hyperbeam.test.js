import assert from "assert"
import { describe, it, before, after, beforeEach } from "node:test"
import { HyperBEAM } from "wao/test"
import { HB } from "wao"

/*
  The link to your HyperBEAM node directory.
  It's relative to your app root folder, not the test folder.
*/
const cwd = ".hyperbeam"

describe("HyperBEAM", function () {
    let hbeam, hb

    // start a hyperbeam node and wait till it's ready, reset storage for test
    before(async () => {
        console.log("Starting HyperBEAM node...")
        const hyperbeam = new HyperBEAM({
            cwd,
            reset: false,
            wallet: "test/admissible-report-wallet.json"
        })

        console.log("Wallet address (from JWK):", hyperbeam.addr)
        console.log("Node URL:", hyperbeam.url)
        console.log("Wallet file:", hyperbeam.wallet)

        // Wait for node to start
        await new Promise(resolve => setTimeout(resolve, 5000))

        // Try to manually initialize HB client with debug
        try {
            console.log("Attempting to fetch address...")
            const address = await fetch(`${hyperbeam.url}/~meta@1.0/info/address`).then(r => r.text())
            console.log("Fetched address (from node):", address)
            console.log("Addresses match:", address === hyperbeam.addr)

            console.log("Attempting to initialize HB client...")
            hb = await new HB({ url: hyperbeam.url }).init(hyperbeam.jwk)
            console.log("HB client initialized successfully")

            hbeam = hyperbeam
            hbeam.hb = hb
        } catch (error) {
            console.error("Error during HB initialization:", error)
            console.error("Error stack:", error.stack)
            throw error
        }

        if (!hbeam) {
            throw new Error("HyperBEAM node failed to start")
        }
    })

    beforeEach(async () => (hb = hbeam.hb))

    // kill the node after testing
    after(async () => {
        if (hbeam && hbeam.kill) {
            hbeam.kill()
        }
    })

    it("should run a HyperBEAM node", async () => {
        // change config
        await hb.post({ path: "/~meta@1.0/info", test_config: "abc" })

        // get config
        const { out } = await hb.get({ path: "/~meta@1.0/info" })
        assert.equal(out.test_config, "abc")
    })
})